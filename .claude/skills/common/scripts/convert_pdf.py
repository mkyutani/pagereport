#!/usr/bin/env python3
"""
PDF to Markdown converter using docling-serve container.

Usage:
    python3 convert_pdf.py <pdf_path> [output_md_path]

Arguments:
    pdf_path: Path to the PDF file to convert
    output_md_path: Optional path to save the Markdown output (default: stdout)

Returns:
    0 on success, 1 on error
"""

import subprocess
import json
import sys
import os


def check_docling_container():
    """Check if docling-serve container is running."""
    try:
        result = subprocess.run(
            ['docker', 'ps'],
            capture_output=True,
            text=True,
            check=True
        )
        return 'docling-server' in result.stdout
    except subprocess.CalledProcessError:
        return False


def start_docling_container():
    """Start docling-serve container if not running."""
    print("Starting docling-serve container...", file=sys.stderr)
    try:
        subprocess.run(
            ['docker', 'run', '-d', '-p', '5001:5001',
             '--name', 'docling-server',
             'quay.io/docling-project/docling-serve'],
            capture_output=True,
            text=True,
            check=True
        )
        print("Container started successfully", file=sys.stderr)
        return True
    except subprocess.CalledProcessError as e:
        print(f"Failed to start container: {e.stderr}", file=sys.stderr)
        return False


def convert_pdf_to_markdown(pdf_path):
    """Convert PDF to Markdown using docling API.

    Args:
        pdf_path: Path to the PDF file

    Returns:
        Markdown content as string, or None on error
    """
    if not os.path.exists(pdf_path):
        print(f"Error: PDF file not found: {pdf_path}", file=sys.stderr)
        return None

    # Check if container is running
    if not check_docling_container():
        print("docling-serve container is not running", file=sys.stderr)
        if not start_docling_container():
            return None
        # Wait a few seconds for container to be ready
        import time
        print("Waiting for container to be ready...", file=sys.stderr)
        time.sleep(5)

    # Call docling API
    try:
        result = subprocess.run(
            [
                'curl', '-s', '-X', 'POST',
                'http://localhost:5001/v1/convert/file',
                '-F', f'files=@{pdf_path}'
            ],
            capture_output=True,
            text=True,
            check=True,
            timeout=300  # 5 minutes timeout
        )

        # Parse JSON response
        data = json.loads(result.stdout)

        if 'document' in data and 'md_content' in data['document']:
            return data['document']['md_content']
        else:
            print(f"Unexpected response format: {data}", file=sys.stderr)
            return None

    except subprocess.CalledProcessError as e:
        print(f"curl command failed: {e.stderr}", file=sys.stderr)
        return None
    except subprocess.TimeoutExpired:
        print("Conversion timeout (5 minutes)", file=sys.stderr)
        return None
    except json.JSONDecodeError as e:
        print(f"Failed to parse JSON response: {e}", file=sys.stderr)
        print(f"Response: {result.stdout[:500]}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        return None


def main():
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        sys.exit(1)

    pdf_path = sys.argv[1]
    output_path = sys.argv[2] if len(sys.argv) > 2 else None

    # Convert PDF
    markdown = convert_pdf_to_markdown(pdf_path)

    if markdown is None:
        sys.exit(1)

    # Output
    if output_path:
        try:
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(markdown)
            print(f"Markdown saved to: {output_path}", file=sys.stderr)
        except IOError as e:
            print(f"Failed to write output file: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        print(markdown)

    sys.exit(0)


if __name__ == '__main__':
    main()
